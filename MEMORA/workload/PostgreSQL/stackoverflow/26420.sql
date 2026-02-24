WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageUserReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        PH.PostId
),
TopEditedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.LastActivityDate,
        COALESCE(E.EditCount, 0) AS EditCount,
        E.LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistoryStats E ON P.Id = E.PostId
    WHERE 
        P.PostTypeId = 1  
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
    LIMIT 10
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.AverageUserReputation,
    E.PostId,
    E.Title,
    E.ViewCount,
    E.Score,
    E.LastActivityDate,
    E.EditCount,
    E.LastEditDate
FROM 
    TopTags T
JOIN 
    TopEditedPosts E ON E.PostId IN (
        SELECT 
            P.Id
        FROM 
            Posts P
        WHERE 
            P.Tags LIKE '%' || T.TagName || '%'
    )
WHERE 
    T.Rank <= 5 
ORDER BY 
    T.PostCount DESC, E.Score DESC;