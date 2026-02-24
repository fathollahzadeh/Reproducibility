WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        us.TotalViews,
        us.TotalScore,
        us.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserID
    WHERE 
        rp.Rank <= 5
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.TotalViews,
    ps.TotalScore,
    ps.Reputation
FROM 
    PostStatistics ps
ORDER BY 
    ps.TotalScore DESC, ps.ViewCount DESC
LIMIT 10;
