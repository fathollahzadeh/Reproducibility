
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        CASE 
            WHEN U.AccountId IS NOT NULL THEN 'Linked'
            ELSE 'Standalone'
        END AS AccountStatus,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END), 0) AS PositiveVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NegativeVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation, U.Views, U.AccountId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        COUNT(CM.Id) AS CommentCount,
        COUNT(CASE WHEN B.Class = 1 THEN B.Id END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN B.Id END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN B.Id END) AS BronzeBadges
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId, P.Title, P.CreationDate, P.ViewCount, P.AnswerCount
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(DISTINCT PH.Id) AS HistoryCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
FinalResults AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.Views,
        U.AccountStatus,
        PD.PostId,
        PD.Title,
        PD.ViewCount,
        PD.AnswerCount,
        PD.CommentCount,
        PHS.LastEditDate,
        PHS.HistoryCount,
        PHS.HistoryTypes,
        U.PositiveVotes,
        U.NegativeVotes,
        (U.PositiveVotes - U.NegativeVotes) AS VoteBalance,
        CASE 
            WHEN PD.PostTypeId = 1 AND PD.AnswerCount > 0 THEN 'Question with Answers'
            WHEN PD.PostTypeId = 1 AND PD.AnswerCount = 0 THEN 'Unanswered Question'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        UserStats U
    JOIN 
        PostDetails PD ON U.UserId = PD.OwnerUserId
    LEFT JOIN 
        PostHistorySummary PHS ON PD.PostId = PHS.PostId
)
SELECT 
    *,
    CASE 
        WHEN VoteBalance > 10 THEN 'Highly Engaged'
        WHEN VoteBalance BETWEEN 1 AND 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    FinalResults
ORDER BY 
    Reputation DESC, 
    ViewCount DESC 
LIMIT 100;
