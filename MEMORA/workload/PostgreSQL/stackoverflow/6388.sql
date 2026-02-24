WITH PostVoteStats AS (
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
UserBadgeStats AS (
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
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PS.VoteCount,
        PS.UpVotes,
        PS.DownVotes,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        UBadges.BadgeCount,
        UBadges.GoldBadges,
        UBadges.SilverBadges,
        UBadges.BronzeBadges
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        PostVoteStats PS ON P.Id = PS.PostId
    LEFT JOIN 
        UserBadgeStats UBadges ON U.Id = UBadges.UserId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.VoteCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.OwnerDisplayName,
    PS.OwnerReputation,
    PS.BadgeCount,
    PS.GoldBadges,
    PS.SilverBadges,
    PS.BronzeBadges,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PS.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Posts P2 WHERE P2.ParentId = PS.PostId AND P2.PostTypeId = 2) AS AnswerCount
FROM 
    PostSummary PS
ORDER BY 
    PS.VoteCount DESC, PS.CreationDate DESC
LIMIT 100;
