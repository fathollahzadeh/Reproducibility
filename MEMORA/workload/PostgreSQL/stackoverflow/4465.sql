
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeletedVotes,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.Score > 10
    AND 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
PostHistoryRecent AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    p.Title AS PopularPostTitle,
    p.Score AS PopularPostScore,
    p.ViewCount AS PopularPostViewCount,
    ph.UserDisplayName AS LastActionUser,
    ph.CreationDate AS LastActionDate,
    ph.PostHistoryTypeId AS LastActionType,
    CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
        WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
        ELSE 'Other'
    END AS ActionDescription
FROM 
    UserVoteSummary uvs
JOIN 
    PopularPosts p ON uvs.Upvotes > 5
LEFT JOIN 
    PostHistoryRecent ph ON p.PostId = ph.PostId AND ph.rn = 1
WHERE 
    uvs.Rank <= 10
ORDER BY 
    uvs.Upvotes DESC, p.Score DESC;
