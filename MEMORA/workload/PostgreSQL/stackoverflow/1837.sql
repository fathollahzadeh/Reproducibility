
WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY Users.Id, Users.Reputation
), UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
), TopAnsweredQuestions AS (
    SELECT 
        Posts.Id AS QuestionId,
        Posts.Title,
        COUNT(Posts.AnswerCount) AS TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY COUNT(Posts.AnswerCount) DESC) AS Rank
    FROM Posts
    WHERE Posts.PostTypeId = 1
    GROUP BY Posts.Id, Posts.Title
)
SELECT 
    u.UserId,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(taq.TotalAnswers, 0) AS TotalAnswersForTopQuestion,
    COALESCE(taq.Title, 'None') AS TopQuestionTitle,
    CASE 
        WHEN u.PostCount > 10 AND u.Reputation > 1000 THEN 'Active Contributor' 
        ELSE 'Newbie' 
    END AS UserStatus
FROM UserReputation u
LEFT JOIN UserBadges ub ON u.UserId = ub.UserId
LEFT JOIN TopAnsweredQuestions taq ON taq.Rank = 1
WHERE u.Reputation IS NOT NULL
ORDER BY u.Reputation DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
