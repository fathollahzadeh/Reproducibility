
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(c.Id) AS CommentsCount,
        COUNT(b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(v.Id) AS VotesCount,
        COUNT(c.Id) AS CommentsCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostsCount,
    ua.TotalScore,
    ua.CommentsCount,
    ua.BadgesCount,
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score AS PostScore,
    pa.VotesCount,
    pa.CommentsCount AS PostCommentsCount,
    pa.LastEditedDate
FROM 
    UserActivity ua
JOIN 
    PostActivity pa ON ua.UserId = pa.PostId
ORDER BY 
    ua.TotalScore DESC, ua.PostsCount DESC;
