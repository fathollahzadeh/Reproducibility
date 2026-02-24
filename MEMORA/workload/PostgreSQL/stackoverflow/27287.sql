
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
MostActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.AnswerCount,
        P.CommentCount,
        COUNT(C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COUNT(C.Id) DESC) AS CommentRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.AnswerCount, P.CommentCount
),
PopularTags AS (
    SELECT 
        Tags.TagName,
        COUNT(P.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM Tags
    JOIN Posts P ON P.Tags LIKE CONCAT('%<', Tags.TagName, '>%') 
    GROUP BY Tags.TagName
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN V.VoteTypeId = 5 THEN 1 ELSE 0 END) AS TotalFavorites
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
)
SELECT 
    UB.DisplayName,
    UB.Reputation,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    MAP.Title AS MostActivePostTitle,
    MAP.TotalComments AS MostActivePostComments,
    PT.TagName AS PopularTagName,
    PT.PostCount AS PopularTagPostCount,
    UE.TotalUpVotes,
    UE.TotalDownVotes,
    UE.TotalFavorites
FROM UserBadges UB
JOIN MostActivePosts MAP ON MAP.CommentRank = 1 
JOIN PopularTags PT ON PT.TagRank <= 5 
JOIN UserEngagement UE ON UB.UserId = UE.UserId
ORDER BY UB.Reputation DESC, UB.BadgeCount DESC, MAP.TotalComments DESC;
