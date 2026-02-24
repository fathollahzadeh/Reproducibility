WITH RankedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL
),
TopQuestions AS (
    SELECT 
        Q.QuestionId,
        Q.Title,
        Q.Tags,
        Q.CreationDate,
        Q.Score,
        Q.OwnerDisplayName
    FROM 
        RankedQuestions Q
    WHERE 
        Q.ScoreRank <= 10
),
QuestionTags AS (
    SELECT 
        T.TagName,
        COUNT(Q.QuestionId) AS QuestionCount
    FROM 
        TopQuestions Q
    CROSS JOIN 
        UNNEST(string_to_array(Q.Tags, '><')) AS T(TagName)
    GROUP BY 
        T.TagName
),
MostPopularTags AS (
    SELECT 
        TagName,
        QuestionCount,
        RANK() OVER (ORDER BY QuestionCount DESC) AS PopularityRank
    FROM 
        QuestionTags
)
SELECT 
    MPT.TagName,
    MPT.QuestionCount,
    (SELECT COUNT(*) FROM Posts WHERE Tags LIKE '%' || MPT.TagName || '%') AS TotalQuestionsWithTag,
    (SELECT COUNT(*) FROM Badges B JOIN Users U ON B.UserId = U.Id WHERE U.Reputation > 1000) AS ActiveUsersWithBadges,
    (SELECT COUNT(*) FROM Votes V WHERE V.VoteTypeId = 2 AND EXISTS (SELECT 1 FROM Posts P WHERE P.Id = V.PostId AND P.Tags LIKE '%' || MPT.TagName || '%')) AS UpvotesForTag
FROM 
    MostPopularTags MPT
WHERE 
    MPT.PopularityRank <= 5
ORDER BY 
    MPT.PopularityRank;
