
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        t.TagName
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= '2023-10-01 12:34:56'::timestamp - INTERVAL '1 year'
        AND ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
FinalSummary AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.AvgUserReputation,
        pi.UpVotes,
        pi.DownVotes,
        pi.CommentCount,
        phs.EditCount,
        phs.UniqueEditors
    FROM 
        TagStats ts
    LEFT JOIN 
        PostInteractions pi ON pi.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%')
    LEFT JOIN 
        PostHistorySummary phs ON phs.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%')
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    AvgUserReputation,
    COALESCE(SUM(UpVotes), 0) AS TotalUpVotes,
    COALESCE(SUM(DownVotes), 0) AS TotalDownVotes,
    COALESCE(SUM(CommentCount), 0) AS TotalComments,
    COALESCE(SUM(EditCount), 0) AS TotalEdits,
    COALESCE(SUM(UniqueEditors), 0) AS TotalUniqueEditors
FROM 
    FinalSummary
GROUP BY 
    TagName, PostCount, TotalViews, AvgUserReputation
ORDER BY 
    TotalViews DESC;
