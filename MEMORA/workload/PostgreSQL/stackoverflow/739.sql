
WITH PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, u.DisplayName
),
TopUsers AS (
    SELECT 
        Owner, 
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        PostActivity
    WHERE 
        ActivityRank <= 10
    GROUP BY 
        Owner
)
SELECT 
    tu.Owner,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    CASE 
        WHEN tu.TotalComments IS NULL THEN 'No Comments'
        ELSE 'Has Comments' 
    END AS CommentsStatus,
    CASE 
        WHEN tu.TotalUpVotes > tu.TotalDownVotes THEN 'Positive Feedback'
        WHEN tu.TotalUpVotes < tu.TotalDownVotes THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS FeedbackSummary
FROM 
    TopUsers tu
ORDER BY 
    tu.TotalComments DESC, tu.TotalUpVotes DESC;
