
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserId AS LastEditorUserId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(ph.Id) AS TotalEdits
    FROM
        Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, ph.UserId
)

SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    phs.PostId,
    phs.Title,
    phs.CreationDate,
    phs.LastEditorUserId,
    phs.LastEditDate,
    phs.TotalEdits
FROM
    UserPostStats ups
LEFT JOIN PostHistoryStats phs ON ups.UserId = phs.LastEditorUserId
ORDER BY
    ups.TotalPosts DESC, ups.TotalUpVotes DESC;
