WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        MAX(P.ViewCount) AS MaxViews,
        MIN(P.CreationDate) AS FirstPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
VoteSummary AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.QuestionCount, 0) AS QuestionCount,
    COALESCE(PS.AnswerCount, 0) AS AnswerCount,
    COALESCE(VS.TotalVotes, 0) AS TotalVotes,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN COALESCE(PS.FirstPostDate, cast('2024-10-01 12:34:56' as timestamp)) > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        THEN 'Active'
        ELSE 'Inactive' 
    END AS UserActivityStatus,
    CONCAT('User: ', U.DisplayName, '; Badges: ', COALESCE(UB.BadgeCount, 0), 
           '; Posts: ', COALESCE(PS.PostCount, 0), 
           '; Questions: ', COALESCE(PS.QuestionCount, 0), 
           '; Answers: ', COALESCE(PS.AnswerCount, 0), 
           '; Votes: ', COALESCE(VS.TotalVotes, 0)) AS Summary
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    VoteSummary VS ON U.Id = VS.UserId
WHERE 
    (UPPER(U.DisplayName) LIKE '%SQL%' OR U.Location IS NOT NULL) 
    AND (UB.BadgeCount > 0 OR PS.PostCount > 0)
ORDER BY 
    BadgeCount DESC, 
    PostCount DESC NULLS LAST, 
    TotalVotes DESC;