
WITH PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        p.OwnerUserId
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Posts a ON p.Id = a.ParentId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserContribution AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    ua.UserId,
    ua.DisplayName,
    ua.QuestionCount,
    ua.TotalViews,
    ua.TotalScore,
    ua.TotalBadges,
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.AnswerCount
FROM
    UserContribution ua
LEFT JOIN
    PostActivity pa ON ua.UserId = pa.OwnerUserId
ORDER BY
    ua.TotalScore DESC, ua.TotalViews DESC;
