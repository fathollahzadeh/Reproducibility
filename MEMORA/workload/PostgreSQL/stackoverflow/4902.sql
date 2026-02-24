WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.OwnerUserId
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes
    FROM
        Users u
    JOIN
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE
        rp.Rank <= 5
    GROUP BY
        u.Id, u.DisplayName
)
SELECT 
    tc.*,
    CASE 
        WHEN tc.TotalUpVotes > tc.TotalDownVotes THEN 'Positive Contributor'
        WHEN tc.TotalUpVotes < tc.TotalDownVotes THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributorType
FROM
    TopContributors tc
ORDER BY 
    tc.TotalUpVotes DESC;