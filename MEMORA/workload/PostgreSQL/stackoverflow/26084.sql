WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        Reputation > 0
),
QuestionTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
),
PopularQuestions AS (
    SELECT 
        Q.Id AS QuestionId,
        Q.Title, 
        Q.ViewCount, 
        QT.Tags
    FROM 
        Posts Q
    JOIN 
        QuestionTags QT ON Q.Id = QT.PostId
    WHERE 
        Q.PostTypeId = 1
    ORDER BY 
        Q.ViewCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    Q.QuestionId,
    Q.Title,
    Q.ViewCount,
    Q.Tags
FROM 
    TopUsers U
JOIN 
    PopularQuestions Q ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = Q.QuestionId)
ORDER BY 
    U.Rank, Q.ViewCount DESC;
