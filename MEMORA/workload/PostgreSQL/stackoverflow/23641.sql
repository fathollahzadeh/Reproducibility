WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PS.PostCount,
        PS.TotalViews,
        PS.QuestionCount,
        PS.AnswerCount,
        RANK() OVER (ORDER BY PS.TotalViews DESC, UB.BadgeCount DESC) AS UserRank
    FROM 
        Users U
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
),
TopPostStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.UserRank,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedUsers U
    JOIN 
        Posts P ON U.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    TPS.UserId,
    TPS.DisplayName,
    TPS.UserRank,
    TPS.PostId,
    TPS.Title,
    TPS.CreationDate,
    TPS.Score,
    TPS.ViewCount,
    TPS.CommentCount,
    COALESCE(TPS.UpVotes, 0) - COALESCE(TPS.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN TPS.Score > 0 THEN 'Positive'
        WHEN TPS.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    RANK() OVER (PARTITION BY TPS.UserId ORDER BY TPS.ViewCount DESC, TPS.Score DESC) AS PostRank
FROM 
    TopPostStats TPS
ORDER BY 
    TPS.UserRank, NetVotes DESC;