
WITH TagStats AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' ', u.Reputation), ', ') AS UserContributors,
        MAX(p.CreationDate) AS LastPostDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        t.TagName
), 

AggregateStats AS (
    SELECT 
        TagName,
        PostCount,
        UserContributors,
        LastPostDate,
        TotalUpVotes - TotalDownVotes AS NetVotes
    FROM 
        TagStats
)

SELECT 
    TagName,
    PostCount,
    UserContributors,
    LastPostDate,
    NetVotes,
    CASE 
        WHEN PostCount = 0 THEN 'No Posts' 
        WHEN NetVotes > 0 THEN 'Positive Engagement' 
        WHEN NetVotes < 0 THEN 'Negative Engagement' 
        ELSE 'Neutral Engagement' 
    END AS EngagementStatus
FROM 
    AggregateStats
WHERE 
    PostCount > 10 
ORDER BY 
    NetVotes DESC, LastPostDate DESC;
