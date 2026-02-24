WITH RecursiveTagCount AS (
    SELECT 
        Tags.TagName, 
        COUNT(DISTINCT Posts.Id) AS PostCount
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
), 
UserReputationRank AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
), 
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
    ORDER BY 
        P.Score DESC
    LIMIT 10
)
SELECT 
    TAGS.TagName,
    TAGS.PostCount,
    UDR.DisplayName AS TopUser,
    UDR.Reputation AS UserReputation,
    TP.Title AS TopPostTitle,
    TP.ViewCount AS TopPostViews,
    TP.AnswerCount AS TopPostAnswers,
    TP.CommentCount AS TopPostComments
FROM 
    RecursiveTagCount TAGS
JOIN 
    UserReputationRank UDR ON UDR.ReputationRank = 1
JOIN 
    TopPosts TP ON TP.AcceptedAnswerId = UDR.UserId
WHERE 
    TAGS.PostCount > 5 
ORDER BY 
    TAGS.PostCount DESC, 
    UDR.Reputation DESC;
