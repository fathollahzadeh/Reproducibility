WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AverageScore,
        SUM(COALESCE(UPV.VoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(DPV.VoteCount, 0)) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount 
        FROM Votes 
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) UPV ON P.Id = UPV.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount 
        FROM Votes 
        WHERE VoteTypeId = 3 
        GROUP BY PostId
    ) DPV ON P.Id = DPV.PostId
    GROUP BY 
        U.Id, U.DisplayName
), UserBadgeCounts AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), UserContributions AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.PositivePosts,
        UPS.NegativePosts,
        UPS.AverageScore,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        UPS.TotalUpVotes,
        UPS.TotalDownVotes
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        UserBadgeCounts UBC ON UPS.UserId = UBC.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    PositivePosts,
    NegativePosts,
    AverageScore,
    BadgeCount,
    TotalUpVotes,
    TotalDownVotes
FROM 
    UserContributions
WHERE 
    TotalPosts > 10 
ORDER BY 
    AverageScore DESC, TotalPosts DESC;