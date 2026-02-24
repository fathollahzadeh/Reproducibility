WITH TagDetails AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        COALESCE(a.Score, 0) AS AnswerScore,
        (SELECT COUNT(*) FROM Posts AS sub WHERE sub.Tags LIKE '%' || t.TagName || '%' AND sub.PostTypeId = 2) AS AnswerCount,
        (SELECT COUNT(*) FROM Comments AS c WHERE c.PostId = p.Id) AS CommentCount
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE
        t.Count > 100 
),
RankedTags AS (
    SELECT
        TagId,
        TagName,
        COUNT(DISTINCT PostTitle) AS PostCount,
        AVG(AnswerScore) AS AvgAnswerScore,
        SUM(CommentCount) AS TotalComments,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT PostTitle) DESC) AS PopularityRank
    FROM
        TagDetails
    GROUP BY
        TagId, TagName
)
SELECT
    rt.TagId,
    rt.TagName,
    rt.PostCount,
    rt.AvgAnswerScore,
    rt.TotalComments
FROM
    RankedTags rt
WHERE
    rt.PopularityRank <= 10 
ORDER BY
    rt.PopularityRank;