WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(vs.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(vs.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes v
        JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        (rp.UpVoteCount - rp.DownVoteCount) AS NetVotes,
        rp.UserPostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1 
        AND rp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
        AND rp.UpVoteCount > 0
),
PostDetails AS (
    SELECT 
        fp.PostId, 
        fp.Title, 
        fp.NetVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount,
        (SELECT AVG(CASE WHEN bp.UserId IS NOT NULL THEN 1 ELSE 0 END) FROM Badges bp WHERE bp.UserId = fp.PostId) AS AvgBadgesPerUser
    FROM 
        FilteredPosts fp
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.NetVotes,
    pd.CommentCount,
    pd.AvgBadgesPerUser,
    u.DisplayName AS OwnerDisplayName,
    CASE 
        WHEN pd.NetVotes IS NULL THEN 'No Votes'
        WHEN pd.NetVotes > 0 THEN 'Positive'
        WHEN pd.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus
FROM 
    PostDetails pd
LEFT JOIN 
    Users u ON pd.PostId = u.Id
WHERE 
    pd.AvgBadgesPerUser IS NOT NULL
ORDER BY 
    pd.NetVotes DESC, 
    pd.CommentCount DESC
LIMIT 10;