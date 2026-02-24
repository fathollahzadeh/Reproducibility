
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 AND
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(c.Score) AS TotalCommentScore,
        STRING_AGG(DISTINCT c.UserDisplayName, ', ') AS CommentUsers
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.CreationDate,
    u.DisplayName AS UserWithMostBadges,
    u.BadgeCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    p.CommentCount AS PostCommentCount,
    p.TotalCommentScore,
    p.CommentUsers
FROM 
    RankedPosts r
LEFT JOIN 
    UserStatistics u ON u.UserId = (SELECT u2.Id FROM Users u2 ORDER BY u2.Reputation DESC LIMIT 1)
LEFT JOIN 
    PostWithComments p ON p.PostId = r.PostId
WHERE 
    r.Rank <= 10
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC
OFFSET 
    0 ROWS FETCH NEXT 10 ROWS ONLY;
