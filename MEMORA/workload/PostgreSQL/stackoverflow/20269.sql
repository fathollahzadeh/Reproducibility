
WITH UserContributions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ContributionRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        uc.UserId,
        uc.DisplayName,
        uc.PostCount,
        uc.Questions,
        uc.Answers,
        uc.TotalBounty,
        uc.ContributionRank,
        ROW_NUMBER() OVER (ORDER BY uc.TotalBounty DESC) AS BountyRank
    FROM UserContributions uc
    WHERE uc.ContributionRank <= 10
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate,
        MAX(CASE WHEN c.UserId IS NOT NULL THEN c.Text ELSE NULL END) AS LastCommentText
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
)
SELECT 
    tu.DisplayName,
    tu.TotalBounty,
    pc.PostId,
    pc.Title,
    pc.CommentCount,
    COALESCE(pc.LastCommentText, 'No comments') AS LastCommentText,
    CASE 
        WHEN pc.CommentCount > 5 THEN 'Highly Discussed'
        WHEN pc.CommentCount > 0 THEN 'Some Discussion'
        ELSE 'No Discussion'
    END AS DiscussionType,
    CASE 
        WHEN tu.Answers > tu.Questions THEN 'Answer-heavy Contributor'
        ELSE 'Question-heavy Contributor'
    END AS ContributorType,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = tu.UserId AND p.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswersCount
FROM TopUsers tu
JOIN PostsWithComments pc ON tu.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = pc.PostId LIMIT 1)
WHERE tu.TotalBounty > 0
ORDER BY tu.TotalBounty DESC, pc.CommentCount DESC
LIMIT 10;
