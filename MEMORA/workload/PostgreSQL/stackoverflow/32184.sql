WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
), PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.CommentCount,
    UA.Upvotes,
    UA.Downvotes,
    CASE 
        WHEN UA.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType,
    PT.TagName,
    PT.PostCount AS PopularTagPostCount
FROM 
    UserActivity UA
FULL OUTER JOIN 
    PopularTags PT ON PT.TagRank <= 5
WHERE 
    UA.PostCount > 0
ORDER BY 
    UA.Reputation DESC, PT.PostCount DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
