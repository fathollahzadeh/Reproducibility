
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), NULL) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND p.ViewCount > 50
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT STRING_AGG(b.Name, ', ') 
         FROM Badges b 
         JOIN Users u ON b.UserId = u.Id 
         WHERE u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)) AS OwnerBadges,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS HasAcceptedAnswer,
        rp.RN
    FROM 
        RecentPosts rp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.OwnerBadges,
    pd.HasAcceptedAnswer,
    CASE 
        WHEN pd.CommentCount = 0 THEN 'No Comments' 
        ELSE 'Has Comments' 
    END AS CommentStatus,
    CASE 
        WHEN pd.UpVotes IS NULL AND pd.DownVotes IS NULL THEN 'No Votes'
        ELSE CONCAT(COALESCE(pd.UpVotes, 0) - COALESCE(pd.DownVotes, 0), ' (Net Votes)')
    END AS NetVotes
FROM 
    PostDetails pd
ORDER BY 
    pd.RN;
