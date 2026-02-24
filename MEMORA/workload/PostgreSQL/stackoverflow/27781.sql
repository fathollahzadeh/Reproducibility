
WITH TagFrequency AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),

MostFrequentTags AS (
    SELECT 
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 10 
),

UserReputationInsights AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

HighReputationTaggers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        TAG.Tag,
        TAG.Frequency,
        COUNT(DISTINCT P.Id) AS QuestionsCreated
    FROM 
        UserReputationInsights UR
    JOIN 
        Posts P ON UR.UserId = P.OwnerUserId
    JOIN 
        TagFrequency TAG ON TAG.Frequency > 5 AND TAG.Tag = ANY(string_to_array(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><'))
    GROUP BY 
        UR.DisplayName, UR.Reputation, TAG.Tag, TAG.Frequency
    HAVING 
        UR.Reputation > 1000 
)

SELECT 
    H.DisplayName,
    H.Reputation,
    H.Tag,
    H.Frequency,
    H.QuestionsCreated
FROM 
    HighReputationTaggers H
JOIN 
    MostFrequentTags M ON H.Tag = M.Tag
WHERE 
    M.Rank <= 10 
ORDER BY 
    H.Frequency DESC, H.Reputation DESC;
