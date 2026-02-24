
WITH MostActiveUsers AS (
    SELECT U.Id, U.DisplayName, COUNT(P.Id) AS PostCount, SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000 
    GROUP BY U.Id, U.DisplayName
),
TopPostTags AS (
    SELECT UNNEST(string_to_array(P.Tags, ',')) AS Tag, COUNT(P.Id) AS PostCount
    FROM Posts P
    WHERE P.PostTypeId = 1 
    GROUP BY Tag
    ORDER BY PostCount DESC
    LIMIT 10
),
TagPostDetails AS (
    SELECT T.Tag, P.Title, P.Score, C.CreationDate
    FROM TopPostTags T
    JOIN Posts P ON P.Tags ILIKE '%' || T.Tag || '%'
    JOIN Comments C ON P.Id = C.PostId
)
SELECT A.DisplayName, T.Tag, COUNT(DISTINCT P.Id) AS RelatedPosts, AVG(P.Score) AS AvgPostScore, MAX(C.CreationDate) AS LastCommentDate
FROM MostActiveUsers A
JOIN TagPostDetails T ON A.DisplayName = T.Tag
JOIN Posts P ON T.Title = P.Title
JOIN Comments C ON P.Id = C.PostId
GROUP BY A.DisplayName, T.Tag
ORDER BY RelatedPosts DESC, AvgPostScore DESC;
