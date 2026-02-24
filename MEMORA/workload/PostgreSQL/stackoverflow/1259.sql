
WITH PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PostTypeId,
        ps.NetScore,
        ps.CommentCount,
        RANK() OVER (PARTITION BY ps.PostTypeId ORDER BY ps.NetScore DESC) AS PostRank
    FROM 
        PostScores ps
),
FilteredTopPosts AS (
    SELECT 
        t.PostId,
        t.Title,
        t.NetScore,
        t.CommentCount,
        pt.Name AS PostTypeName
    FROM 
        TopPosts t
    JOIN 
        PostTypes pt ON t.PostTypeId = pt.Id
    WHERE 
        t.PostRank <= 10
)
SELECT 
    f.*,
    CASE 
        WHEN f.CommentCount > 5 THEN 'Highly Discussed'
        ELSE 'Less Discussion'
    END AS DiscussionType,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = f.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount,
    NULLIF((SELECT AVG(CASE WHEN v.VoteTypeId IN (2, 3) THEN v.VoteTypeId END) FROM Votes v WHERE v.PostId = f.PostId), 0) AS AverageVoteType
FROM 
    FilteredTopPosts f
LEFT JOIN 
    Users u ON f.PostId = u.Id
WHERE 
    u.Reputation IS NOT NULL
ORDER BY 
    f.NetScore DESC;
