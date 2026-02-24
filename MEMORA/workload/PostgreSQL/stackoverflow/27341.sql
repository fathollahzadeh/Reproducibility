
WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPostCount
    FROM Tags tag
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', tag.TagName, '>%')  
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id  
    GROUP BY tag.TagName
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.UpVotesReceived,
        RANK() OVER (ORDER BY ua.UpVotesReceived DESC) AS UserRank
    FROM UserActivity ua
    WHERE ua.QuestionCount > 0
)

SELECT 
    tc.TagName,
    tc.PostCount,
    tc.ClosedPostCount,
    tc.ReopenedPostCount,
    tu.DisplayName AS TopUser,
    tu.UpVotesReceived
FROM TagCounts tc
LEFT JOIN (
    SELECT UserId, DisplayName, UpVotesReceived 
    FROM TopUsers 
    WHERE UserRank = 1  
    LIMIT 1
) tu ON tu.UserId = tu.UserId
ORDER BY tc.PostCount DESC
LIMIT 10;
