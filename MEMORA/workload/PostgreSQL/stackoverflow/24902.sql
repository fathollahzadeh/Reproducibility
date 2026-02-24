
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0)) AS TotalUpVotes,
        SUM(COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0)) AS TotalDownVotes,
        u.Reputation
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
PostClosingStats AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastCloseDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    pcs.LastCloseDate,
    pcs.CloseCount,
    pcs.ReopenCount,
    tt.TagName,
    tt.PostCount
FROM 
    UserPostStats ups
LEFT JOIN 
    PostClosingStats pcs ON ups.TotalQuestions > 0 AND pcs.PostId = (
        SELECT MIN(p.Id) FROM Posts p WHERE p.OwnerUserId = ups.UserId AND p.PostTypeId = 1
    )
JOIN 
    TopTags tt ON tt.PostCount > 0
WHERE 
    ups.TotalUpVotes > ups.TotalDownVotes
    AND ups.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    ups.TotalPosts DESC,
    (ups.TotalUpVotes - ups.TotalDownVotes) DESC;
