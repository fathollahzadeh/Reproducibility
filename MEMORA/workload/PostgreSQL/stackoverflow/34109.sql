WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(BC.TotalBadges, 0) AS TotalBadges,
        BC.GoldBadges,
        BC.SilverBadges,
        BC.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts BC ON U.Id = BC.UserId
    WHERE 
        U.Reputation > 0
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.Id AS OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        COALESCE((SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 8), 0) AS TotalBounty
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AnswerDetails AS (
    SELECT 
        A.Id AS AnswerId,
        A.ParentId AS QuestionId,
        A.Score AS AnswerScore,
        A.CreationDate AS AnswerCreationDate,
        D.OwnerUserId,
        D.OwnerDisplayName,
        D.CommentCount,
        D.TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY A.ParentId ORDER BY A.Score DESC) AS AnswerRank
    FROM 
        Posts A
    JOIN 
        PostDetails D ON A.ParentId = D.PostId
    WHERE 
        A.PostTypeId = 2
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.TotalBadges,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    PD.Title AS QuestionTitle,
    PD.ViewCount,
    PD.Score AS QuestionScore,
    COALESCE(AD.AnswerId, -1) AS AcceptedAnswerId,
    AD.AnswerScore AS MostSupportedAnswerScore,
    AD.AnswerCreationDate AS MostSupportedAnswerDate,
    PD.CommentCount,
    PD.TotalBounty AS QuestionTotalBounty,
    CASE 
        WHEN PD.ViewCount > 1000 THEN 'High Lead'
        WHEN PD.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Lead'
        ELSE 'Low Lead'
    END AS EngagementLevel
FROM 
    TopUsers TU
JOIN 
    PostDetails PD ON TU.UserId = PD.OwnerUserId
LEFT JOIN 
    AnswerDetails AD ON PD.PostId = AD.QuestionId AND AD.AnswerRank = 1
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC, 
    PD.ViewCount DESC;