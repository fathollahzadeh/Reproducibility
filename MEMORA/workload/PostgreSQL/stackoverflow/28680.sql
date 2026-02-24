
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
), 

FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        ViewCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
), 

AggregateStats AS (
    SELECT 
        Tags,
        COUNT(PostId) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        FilteredPosts
    GROUP BY 
        Tags
)

SELECT 
    Tags,
    PostCount,
    TotalViews,
    TotalUpVotes,
    TotalDownVotes,
    ROUND(TotalUpVotes::DECIMAL / NULLIF(PostCount, 0), 2) AS AvgUpVotesPerPost,
    ROUND(TotalDownVotes::DECIMAL / NULLIF(PostCount, 0), 2) AS AvgDownVotesPerPost
FROM 
    AggregateStats 
ORDER BY 
    TotalViews DESC;
