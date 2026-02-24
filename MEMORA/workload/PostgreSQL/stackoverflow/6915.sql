WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Id, 0)) AS TotalComments,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers,
        TotalScore,
        TotalComments,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC, Reputation DESC) AS UserRank
    FROM 
        UserActivity
),
RecentPostHistories AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        p.Body,
        ph.Comment,
        r.UserRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        (SELECT UserId, UserRank 
         FROM TopUsers 
         WHERE UserRank <= 10) r ON ph.UserId = r.UserId
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    AVG(DATE_PART('epoch', cast('2024-10-01 12:34:56' as timestamp) - rp.CreationDate)) AS AvgDaysSincePost,
    MAX(rp.Comment) AS MostRecentComment,
    SUM(rp.UserRank) AS TotalRank
FROM 
    TopUsers u
LEFT JOIN 
    RecentPostHistories rp ON u.UserId = rp.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    RecentPostCount DESC, TotalRank DESC;