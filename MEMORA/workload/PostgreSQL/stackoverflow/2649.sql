
WITH UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS QuestionRank
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT Id FROM Posts)
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersGiven,
        TotalUpvotes,
        TotalDownvotes,
        QuestionRank
    FROM
        UserEngagement
    WHERE
        QuestionsAsked > 0
)
SELECT
    tu.DisplayName,
    tu.QuestionsAsked,
    tu.AnswersGiven,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    (tu.TotalUpvotes - tu.TotalDownvotes) AS NetVotes,
    CASE
        WHEN tu.QuestionRank <= 5 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM
    TopUsers tu
LEFT JOIN
    Badges b ON tu.UserId = b.UserId
WHERE
    b.Class = 1 OR b.Class = 2  
ORDER BY
    tu.QuestionsAsked DESC, NetVotes DESC;
