
WITH RECURSIVE PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS ActivityRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
    UNION ALL
    SELECT
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.PostTypeId,
        pa.Score,
        pa.OwnerUserId,
        pa.AnswerCount,
        pa.CommentCount,
        pa.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pa.OwnerUserId ORDER BY pa.CreationDate DESC) AS ActivityRank
    FROM
        PostActivity pa
    JOIN
        Votes v ON v.PostId = pa.PostId
    WHERE
        v.CreationDate >= DATE('2024-10-01') - INTERVAL '6 months'
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments,
        MAX(p.CreationDate) AS LastPostDate
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalViews,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.LastPostDate,
    ht.Name AS HighScoresType
FROM
    UserPostStats ups
LEFT JOIN
    PostHistory ph ON ups.UserId = ph.UserId
INNER JOIN
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
WHERE
    ups.TotalScore > 100
    AND ups.LastPostDate >= DATE('2024-10-01') - INTERVAL '6 months'
ORDER BY
    ups.TotalScore DESC;
