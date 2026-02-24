
WITH RecursiveUserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
), 

UserRanking AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalUpVotes,
        TotalDownVotes,
        UserRank,
        CASE 
            WHEN PostCount > 100 THEN 'Expert'
            WHEN PostCount BETWEEN 50 AND 100 THEN 'Pro'
            ELSE 'Novice'
        END AS UserLevel
    FROM RecursiveUserPostStats
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagPostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 10
),

TopClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS CloseCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY p.Id, p.Title
    ORDER BY CloseCount DESC
    LIMIT 5
)

SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.PostCount,
    ur.QuestionCount,
    ur.AnswerCount,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    ur.UserLevel,
    tt.TagName,
    tt.TagPostCount,
    cp.Title AS ClosedPostTitle,
    cp.CloseCount AS CloseCount
FROM UserRanking ur
LEFT JOIN PopularTags tt ON ur.UserRank = 1
LEFT JOIN TopClosedPosts cp ON ur.UserRank = 1
ORDER BY ur.UserRank;
