WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagFrequency AS (
    SELECT 
        Tag,
        COUNT(*) AS Frequency
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedQuestions,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalQuestions,
        ua.UpvotedQuestions,
        ua.DownvotedQuestions,
        ua.TotalComments,
        ROW_NUMBER() OVER (ORDER BY ua.TotalQuestions DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalQuestions > 10 
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.UpvotedQuestions,
    tu.DownvotedQuestions,
    tu.TotalComments,
    tf.Tag,
    tf.Frequency
FROM 
    TopUsers tu
JOIN 
    TagFrequency tf ON tf.Tag IN (
        SELECT Tag 
        FROM ProcessedTags pt 
        WHERE pt.PostId IN (
            SELECT p.Id 
            FROM Posts p 
            WHERE p.OwnerUserId = tu.UserId
        )
    )
ORDER BY 
    tu.UserRank, tf.Frequency DESC;