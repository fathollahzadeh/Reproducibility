WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.OwnerUserId END) AS UsersWithAcceptedAnswers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%') 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (
            SELECT 
                PostId,
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
            FROM 
                Votes
            GROUP BY 
                PostId
        ) v ON p.Id = v.PostId
    GROUP BY 
        t.TagName
),
CloseReasonStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        h.PostHistoryTypeId,
        cr.Name AS CloseReason,
        COUNT(h.Id) AS CloseCount
    FROM 
        Posts p
    JOIN 
        PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes cr ON CAST(h.Comment AS INT) = cr.Id
    GROUP BY 
        p.Id, p.Title, h.PostHistoryTypeId, cr.Name
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.UniqueUsers,
    ts.UsersWithAcceptedAnswers,
    COALESCE(c.CloseCount, 0) AS TotalCloseReasons
FROM 
    TagStats ts
LEFT JOIN 
    CloseReasonStats c ON c.PostId = (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.Tags LIKE CONCAT('%', ts.TagName, '%') 
        LIMIT 1
    )
ORDER BY 
    ts.TotalUpVotes DESC, ts.PostCount DESC
LIMIT 100;
