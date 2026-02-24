WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgesCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.Questions,
        UA.Answers,
        UA.ClosedPosts,
        UA.UpVotes,
        UA.DownVotes,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount
    FROM 
        UserActivity UA
    LEFT JOIN 
        BadgesCount BC ON UA.UserId = BC.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    ClosedPosts,
    UpVotes,
    DownVotes,
    BadgeCount,
    (TotalPosts - ClosedPosts) AS ActivePosts,
    (UpVotes - DownVotes) AS VoteBalance
FROM 
    FinalStats
ORDER BY 
    ActivePosts DESC, VoteBalance DESC
LIMIT 10;
