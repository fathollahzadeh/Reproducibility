WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(v.Id) DESC) AS TagRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),

TagAnalytics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes,
        AVG(rp.VoteCount) AS AvgVotesPerPost
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
    JOIN
        RankedPosts rp ON p.Id = rp.PostId
    GROUP BY
        t.TagName
),

TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalUpVotes,
        TotalDownVotes,
        AvgVotesPerPost,
        RANK() OVER (ORDER BY QuestionCount DESC) AS TagRank
    FROM
        TagAnalytics
)

SELECT
    TagName,
    QuestionCount,
    TotalUpVotes,
    TotalDownVotes,
    AvgVotesPerPost,
    TagRank
FROM
    TopTags
WHERE
    TagRank <= 10 
ORDER BY
    QuestionCount DESC;