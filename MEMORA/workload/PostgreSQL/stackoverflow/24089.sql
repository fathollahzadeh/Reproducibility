WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT case when P.PostTypeId = 1 then P.Id end) AS QuestionCount,
        COUNT(DISTINCT case when P.PostTypeId = 2 then P.Id end) AS AnswerCount,
        MAX(P.Score) AS MaxPostScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopVotedUsers AS (
    SELECT 
        UserId, DisplayName, TotalUpVotes, TotalDownVotes, PostCount, 
        QuestionCount, AnswerCount, MaxPostScore, AvgViewCount, VoteRank
    FROM 
        UserVoteStats
    WHERE 
        TotalUpVotes >= 10 OR TotalDownVotes >= 5
),
FrequentBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
    HAVING 
        COUNT(B.Id) > 5
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(B.BadgeNames, 'No Badges') AS BadgeNames,
        TVU.TotalUpVotes,
        TVU.TotalDownVotes,
        TVU.PostCount
    FROM 
        Users U
    LEFT JOIN 
        FrequentBadges B ON U.Id = B.UserId
    LEFT JOIN 
        TopVotedUsers TVU ON U.Id = TVU.UserId
)
SELECT 
    UE.DisplayName,
    UE.PostCount,
    UE.BadgeCount,
    UE.BadgeNames,
    LEAD(UE.BadgeCount) OVER (ORDER BY UE.BadgeCount DESC) AS NextUserBadgeCount,
    CASE 
        WHEN UE.BadgeCount IS NULL THEN 'No badges!'
        ELSE 'Has badges!'
    END AS BadgeStatus,
    COALESCE(UE.TotalUpVotes - UE.TotalDownVotes, 0) AS NetVotes,
    CASE 
        WHEN UE.BadgeCount > 5 AND UE.TotalUpVotes > 50 THEN 'Highly Engaged'
        WHEN UE.BadgeCount IS NOT NULL AND UE.TotalUpVotes IS NULL THEN 'Inactive'
        ELSE 'Average User'
    END AS EngagementLevel
FROM 
    UserEngagement UE
WHERE 
    (UE.BadgeCount IS NOT NULL AND UE.BadgeCount > 0)
    OR (UE.PostCount > 3)
ORDER BY 
    UE.BadgeCount DESC, UE.DisplayName;