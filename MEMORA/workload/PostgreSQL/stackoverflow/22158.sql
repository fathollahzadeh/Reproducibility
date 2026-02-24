
WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Title,
        p.Tags,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(ph.Comment, 'No Comments') AS LastHistoryComment,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(ph2.CreationDate)
            FROM PostHistory ph2
            WHERE ph2.PostId = p.Id
            AND ph2.PostHistoryTypeId IN (10, 11, 12) 
        )
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),

TagUsage AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.TagName
),

UserActivity AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY
        u.Id
)

SELECT
    rp.PostId,
    rp.Title,
    rp.Tags,
    su.TotalBounties,
    COALESCE(tu.PostCount, 0) AS TotalPostsWithTag,
    COALESCE(tu.QuestionCount, 0) AS TotalQuestions,
    COALESCE(tu.AnswerCount, 0) AS TotalAnswers,
    (SELECT COUNT(DISTINCT c.Id)
     FROM Comments c
     WHERE c.PostId = rp.PostId) AS TotalComments,
    CASE
        WHEN rp.LastHistoryComment IS NULL THEN 'No History Available'
        ELSE rp.LastHistoryComment
    END AS LastActionComment
FROM
    RecentPosts rp
JOIN
    UserActivity su ON su.UserId = (
        SELECT OwnerUserId
        FROM Posts
        WHERE Id = rp.PostId
    )
LEFT JOIN
    TagUsage tu ON tu.TagName = ANY(string_to_array(rp.Tags, '>'))
WHERE
    rp.PostTypeId = 1 
    AND (su.PostsCount > 1 OR su.TotalBounties > 0) 
ORDER BY
    rp.CreationDate DESC;
