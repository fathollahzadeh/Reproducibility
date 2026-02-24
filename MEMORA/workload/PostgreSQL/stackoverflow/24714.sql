WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
), FilteredPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostRank,
        rp.UpVotes,
        rp.DownVotes,
        rp.UserReputation,
        CASE 
            WHEN rp.UserReputation IS NULL THEN 'Unknown Reputation'
            WHEN rp.UserReputation > 1000 THEN 'High Reputation'
            ELSE 'Moderate Reputation'
        END AS ReputationCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 
        AND rp.ViewCount > 10
)

SELECT 
    fp.PostID,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.ReputationCategory,
    COALESCE(c.CommentCount, 0) AS TotalComments
FROM 
    FilteredPosts fp
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON fp.PostID = c.PostId
WHERE 
    fp.Score > 5 
ORDER BY 
    fp.ViewCount DESC,
    fp.Score DESC;