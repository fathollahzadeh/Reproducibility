WITH TagPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
AggregatedData AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT t.Id) AS TagCount,
        AVG(pd.CommentCount) AS AvgComments,
        SUM(pd.UpVotes) AS TotalUpVotes,
        SUM(pd.DownVotes) AS TotalDownVotes
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        TagPostDetails pd ON pd.PostId = p.Id
    GROUP BY 
        t.TagName
)
SELECT 
    a.TagName,
    a.TagCount,
    a.AvgComments,
    a.TotalUpVotes,
    a.TotalDownVotes,
    CASE 
        WHEN a.TotalUpVotes > a.TotalDownVotes THEN 'Positive'
        WHEN a.TotalUpVotes < a.TotalDownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    ROW_NUMBER() OVER (ORDER BY a.TotalUpVotes DESC) AS Rank
FROM 
    AggregatedData a
WHERE 
    a.TagCount > 5
ORDER BY 
    a.TotalUpVotes DESC
LIMIT 10;