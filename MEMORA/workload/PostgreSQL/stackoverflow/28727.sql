WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        AnswerCount,
        CommentCount,
        UpVotes,
        DownVotes
    FROM
        RankedPosts
    WHERE
        rn = 1
)
SELECT
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.AnswerCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    CONCAT('Upvotes: ', fp.UpVotes, ', Downvotes: ', fp.DownVotes) AS VoteSummary,
    ARRAY_LENGTH(string_to_array(fp.Body, ' '), 1) AS WordCount,
    DATE_PART('year', AGE(fp.CreationDate)) AS AgeInYears,
    CASE
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive Engagement'
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM
    FilteredPosts fp
WHERE
    fp.AnswerCount > 0
ORDER BY
    fp.UpVotes DESC, 
    fp.CreationDate DESC;