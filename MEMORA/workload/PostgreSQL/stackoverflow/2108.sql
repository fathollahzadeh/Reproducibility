WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, B.Class
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN VT.Id = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Id = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY V.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(BB.BadgeCount, 0) AS BadgeCount,
    COALESCE(BB.Class, 0) AS BadgeClass,
    UPS.TotalPosts,
    UPS.Questions,
    UPS.Answers,
    UPS.AcceptedAnswers,
    COALESCE(UV.TotalVotes, 0) AS TotalVotes,
    COALESCE(UV.UpVotes, 0) AS UpVotes,
    COALESCE(UV.DownVotes, 0) AS DownVotes
FROM Users U
LEFT JOIN UserBadges BB ON U.Id = BB.UserId 
LEFT JOIN UserPostStats UPS ON U.Id = UPS.UserId
LEFT JOIN UserVotes UV ON U.Id = UV.UserId
WHERE (UPS.TotalPosts > 0 OR UV.TotalVotes > 0)
ORDER BY UPS.TotalPosts DESC, UV.TotalVotes DESC
LIMIT 100;
