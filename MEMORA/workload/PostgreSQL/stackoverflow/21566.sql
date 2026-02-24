
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS InitialTitleDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedPost,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.Title, pt.Name, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.UpvotesReceived,
        us.DownvotesReceived,
        ps.PostId,
        ps.Title,
        ps.PostType,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.CommentCount,
        ps.InitialTitleDate,
        ps.ClosedPost,
        ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY ps.CreationDate DESC) AS UserPostRank
    FROM 
        UserStats us
    JOIN 
        PostDetail ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.UpvotesReceived,
    f.DownvotesReceived,
    f.PostId,
    f.Title,
    f.PostType,
    f.CreationDate,
    f.ViewCount,
    f.Score,
    f.CommentCount,
    f.InitialTitleDate,
    f.ClosedPost,
    CASE 
        WHEN f.UserPostRank = 1 THEN 'Most Recent Post'
        ELSE NULL 
    END AS RankDescription
FROM 
    FinalStats f
WHERE 
    f.Reputation > 500 AND 
    (f.ClosedPost IS NULL OR f.Score > 0)
ORDER BY 
    f.Reputation DESC, 
    f.UserId, 
    f.CreationDate DESC
LIMIT 100 OFFSET 0;
