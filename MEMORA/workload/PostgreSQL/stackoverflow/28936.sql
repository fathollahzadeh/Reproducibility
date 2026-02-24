
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT t.TagName) AS TagCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
ClosedPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.FirstChangeDate,
        ph.LastChangeDate,
        ptd.UpVotes,
        ptd.DownVotes,
        ptd.TagCount,
        ptd.CloseVotes
    FROM 
        PostHistoryAnalysis ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    JOIN 
        PostTagCounts ptd ON ptd.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 12) 
)

SELECT 
    cpd.PostId,
    cpd.Title,
    EXTRACT(YEAR FROM cpd.CreationDate) AS CreationYear,
    cpd.UpVotes,
    cpd.DownVotes,
    cpd.TagCount,
    cpd.CloseVotes,
    DATE_PART('day', cpd.LastChangeDate - cpd.FirstChangeDate) AS DurationInDays
FROM 
    ClosedPostDetails cpd
WHERE 
    cpd.CloseVotes > 0 
ORDER BY 
    cpd.CloseVotes DESC, CreationYear DESC
LIMIT 100;
