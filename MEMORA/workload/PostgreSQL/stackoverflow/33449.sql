WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  

    UNION ALL

    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        PH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        PostHierarchy PH ON P.ParentId = PH.Id
    WHERE 
        P.PostTypeId = 2  
),
BadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
TopPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        PS.VoteCount,
        PS.UpVotes,
        PS.DownVotes,
        BH.BadgeCount,
        BH.GoldBadges,
        BH.SilverBadges,
        BH.BronzeBadges,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY PS.VoteCount DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        PostVoteSummary PS ON P.Id = PS.PostId
    LEFT JOIN 
        BadgeSummary BH ON P.OwnerUserId = BH.UserId
    WHERE 
        P.PostTypeId = 1  
)

SELECT 
    TH.Title AS QuestionTitle,
    TH.VoteCount,
    TH.UpVotes,
    TH.DownVotes,
    U.DisplayName AS OwnerName,
    U.Reputation AS OwnerReputation,
    CASE 
        WHEN TH.BadgeCount > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasBadges,
    TH.GoldBadges,
    TH.SilverBadges,
    TH.BronzeBadges,
    PH.Level AS AnswerLevel
FROM 
    TopPosts TH
JOIN 
    Users U ON TH.OwnerUserId = U.Id
LEFT JOIN 
    PostHierarchy PH ON TH.Id = PH.ParentId
WHERE 
    TH.Rank <= 5  
ORDER BY 
    TH.VoteCount DESC;