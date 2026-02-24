
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalTagWikis, 
        AvgScore, 
        AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalTagWikis,
    U.AvgScore,
    U.AvgViewCount,
    COALESCE(BadgeCount.BadgeCount, 0) AS TotalBadges,
    COALESCE(VoteCount.VoteCount, 0) AS TotalVotes
FROM 
    TopUsers U
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
) AS BadgeCount ON U.UserId = BadgeCount.UserId
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS VoteCount
    FROM 
        Votes 
    GROUP BY 
        UserId
) AS VoteCount ON U.UserId = VoteCount.UserId
WHERE 
    U.Rank <= 10
ORDER BY 
    U.TotalPosts DESC;
