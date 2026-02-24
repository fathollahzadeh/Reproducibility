WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS AuthorDisplayName,
        u.Reputation AS AuthorReputation,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UpVoteCount
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseEvents
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
EnhancedPostDetails AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Body,
        pd.Tags,
        pd.CreationDate,
        pd.AuthorDisplayName,
        pd.AuthorReputation,
        pd.TagCount,
        pd.AnswerCount,
        pd.UpVoteCount,
        COALESCE(cp.CloseEvents, 0) AS CloseEventCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        ClosedPosts cp ON pd.PostId = cp.PostId
)
SELECT 
    epd.PostId,
    epd.Title,
    epd.Body,
    epd.Tags,
    epd.CreationDate,
    epd.AuthorDisplayName,
    epd.AuthorReputation,
    epd.TagCount,
    epd.AnswerCount,
    epd.UpVoteCount,
    epd.CloseEventCount
FROM 
    EnhancedPostDetails epd
WHERE 
    epd.TagCount > 5
ORDER BY 
    epd.UpVoteCount DESC,
    epd.CreationDate ASC
LIMIT 10;