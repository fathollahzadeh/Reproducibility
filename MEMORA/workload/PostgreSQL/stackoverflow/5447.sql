
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    us.DisplayName,
    us.TotalScore,
    us.TotalPosts,
    us.TotalBadges,
    COUNT(RP.PostId) AS TopQuestions,
    PT.TagName,
    PT.PostCount
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts RP ON us.UserId = RP.OwnerUserId AND RP.Rank <= 5
JOIN 
    PopularTags PT ON PT.PostCount > 0
GROUP BY 
    us.DisplayName, us.TotalScore, us.TotalPosts, us.TotalBadges, PT.TagName, PT.PostCount
ORDER BY 
    us.TotalScore DESC, us.TotalPosts DESC;
