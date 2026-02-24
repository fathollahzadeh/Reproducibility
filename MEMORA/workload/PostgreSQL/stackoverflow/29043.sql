
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),

TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 10 
),

UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        QuestionCount > 5 
)

SELECT 
    T.Tag,
    T.PostCount AS TotalQuestions,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.QuestionCount AS UserQuestionCount,
    U.AnswerCount AS UserAnswerCount,
    U.BadgeCount AS UserBadgeCount
FROM 
    TopTags T
JOIN 
    TopUsers U ON U.QuestionCount = (
        SELECT 
            MAX(QuestionCount) 
        FROM 
            TopUsers 
        WHERE 
            EXISTS (
                SELECT 1 
                FROM Posts P 
                WHERE 
                    P.OwnerUserId = U.UserId 
                    AND T.Tag = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))
            )
    )
ORDER BY 
    T.PostCount DESC, U.Reputation DESC
LIMIT 10;
