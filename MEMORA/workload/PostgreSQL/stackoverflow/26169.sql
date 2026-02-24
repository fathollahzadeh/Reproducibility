WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ptc.TagCount, 0) AS TagCount,
        COALESCE(pv.Upvotes, 0) AS Upvotes,
        COALESCE(pv.Downvotes, 0) AS Downvotes,
        pv.TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTagCounts ptc ON p.Id = ptc.PostId
    LEFT JOIN 
        PostVotes pv ON p.Id = pv.PostId
),
TopActivePosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.TagCount,
        pa.Upvotes,
        pa.Downvotes,
        pa.TotalVotes,
        ROW_NUMBER() OVER (ORDER BY pa.TotalVotes DESC, pa.CreationDate DESC) AS Rank
    FROM 
        PostActivity pa
)
SELECT 
    tap.PostId,
    tap.Title,
    tap.CreationDate,
    tap.TagCount,
    tap.Upvotes,
    tap.Downvotes,
    tap.TotalVotes
FROM 
    TopActivePosts tap
WHERE 
    tap.Rank <= 10
ORDER BY 
    tap.TotalVotes DESC, tap.CreationDate DESC;
